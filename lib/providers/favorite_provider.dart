import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  List<Product> get favorites => List.unmodifiable(_favorites);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Load favorites from Firestore for current user (called on app start)
  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      _favorites.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // ✅ Pastikan data tidak null dan lengkap
        if (data.isEmpty) continue;

        try {
          final product = Product(
            id: (data['id'] ?? doc.id).toString(),
            name: (data['name'] ?? '').toString(),
            brand: (data['brand'] ?? '').toString(),
            description: (data['description'] ?? '').toString(),
            price: _parsePrice(data['price']),
            imageUrl: (data['imageUrl'] ??
                    data['image'] ??
                    'https://via.placeholder.com/150')
                .toString(),
            categories: _safeStringList(data['categories']),
            purchaseOptions: [], // bisa diisi nanti kalau ada data
          );

          _favorites.add(product);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing favorite doc ${doc.id}: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.loadFavorites error: $e');
    }
  }

  /// 🔹 Helper: safely parse price (handle string, int, double, null)
  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  /// 🔹 Helper: safely convert categories to List<String>
  List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// 🔹 Check if product id is in favorites
  bool isFavorite(String id) => _favorites.any((p) => p.id == id);

  /// 🔹 Add/remove favorite (sync to Firestore if logged in)
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;

    // Kalau belum login → hanya update lokal
    if (user == null) {
      if (isFavorite(product.id)) {
        _favorites.removeWhere((p) => p.id == product.id);
      } else {
        _favorites.add(product);
      }
      notifyListeners();
      return;
    }

    final favDocRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(product.id);

    try {
      if (isFavorite(product.id)) {
        await favDocRef.delete();
        _favorites.removeWhere((p) => p.id == product.id);
      } else {
        await favDocRef.set({
          'id': product.id,
          'name': product.name,
          'brand': product.brand,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'categories': product.categories,
          'addedAt': FieldValue.serverTimestamp(),
        });
        _favorites.add(product);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.toggleFavorite error: $e');
      rethrow;
    }
  }

  /// 🔹 Remove favorite by product id (local + Firestore)
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;

    _favorites.removeWhere((p) => p.id == productId);
    notifyListeners();

    if (user == null) return;

    try {
      final favDocRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId);

      await favDocRef.delete();
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.removeFavorite error: $e');
    }
  }
}
