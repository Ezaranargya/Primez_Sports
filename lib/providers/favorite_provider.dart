import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  List<Product> get favorites => List.unmodifiable(_favorites);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Product?> _getProductsFromFirestore(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return Product.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching product from Firestore: $e');
    }
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) print('⚠️ User not logged in, skipping loadFavorites');
      return;
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      _favorites.clear();

      if (kDebugMode) {
        print('📦 Loading ${snapshot.docs.length} favorites from Firestore');
      }

      for(var doc in snapshot.docs) {
        final data = doc.data();
        if (data.isEmpty) continue;

          final productId = data['productId']?.toString() ?? doc.id;
          final product = await _getProductsFromFirestore(productId);
          
          if (product != null) {
            _favorites.add(product);
            if (kDebugMode) print('✅ Loaded favorite: ${product.name}');
          } else {
            if (kDebugMode) print('⚠️ Product not found in Firestore: $productId');
          }
      }

      if (kDebugMode) {
        print('✅ Loaded ${_favorites.length} favorites successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.loadFavorites error: $e');
    }
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<PurchaseOption> _parsePurchaseOptions(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .map((opt) {
          if (opt is! Map) return null;
          return PurchaseOption(
            name: opt['name']?.toString() ?? '',
            storeName: opt['storeName']?.toString() ?? '',
            price: _parsePrice(opt['price']),
            logoUrl: opt['logoUrl']?.toString() ?? '',
            link: opt['link']?.toString() ?? '',
          );
        })
        .whereType<PurchaseOption>()
        .toList();
  }

  bool isFavorite(String id) => _favorites.any((p) => p.id == id);

  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    
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
        
        if (kDebugMode) {
          print('🗑️ Removed ${product.name} from favorites');
        }
      } else {
        await favDocRef.set({
          'productId': product.id,
          'addedAt': FieldValue.serverTimestamp(),
        });
        _favorites.add(product);
        
        if (kDebugMode) {
          print('❤️ Added ${product.name} to favorites with ${product.purchaseOptions.length} purchase options');
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.toggleFavorite error: $e');
      rethrow;
    }
  }

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
      
      if (kDebugMode) {
        print('🗑️ Removed product $productId from Firestore');
      }
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.removeFavorite error: $e');
    }
  }

  Future<void> clearAllFavorites() async {
    final user = _auth.currentUser;

    _favorites.clear();
    notifyListeners();

    if (user == null) return;

    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (kDebugMode) {
        print('🗑️ Cleared all ${snapshot.docs.length} favorites');
      }
    } catch (e) {
      if (kDebugMode) print('❌ FavoriteProvider.clearAllFavorites error: $e');
    }
  }
}