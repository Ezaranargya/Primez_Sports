import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/models/product_model.dart';

class FavoriteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Product> _favorites = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<Product> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  FavoriteProvider() {
    _initializeFavorites();
  }
  Future<void> _initializeFavorites() async {
    if (_isInitialized) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      _isInitialized = true;
      return;
    }

    await loadFavorites();
    _isInitialized = true;
  }
  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ User belum login, tidak bisa load favorites');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Loading favorites dari Firebase untuk user: ${user.uid}');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      _favorites.clear();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final product = Product.fromMap(doc.id, data);
          _favorites.add(product);
          print('✅ Loaded favorite: ${product.name}');
        } catch (e) {
          print('❌ Error parsing favorite product ${doc.id}: $e');
        }
      }

      print('✅ Total favorites loaded: ${_favorites.length}');
    } catch (e) {
      print('❌ Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  bool isFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(product.id);

    try {
      if (isFavorite(product.id)) {
        await docRef.delete();
        _favorites.removeWhere((p) => p.id == product.id);
        print('🗑️ Removed from favorites: ${product.name}');
      } else {
        await docRef.set(product.toMap());
        _favorites.add(product);
        print('❤️ Added to favorites: ${product.name}');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .delete();

      _favorites.removeWhere((p) => p.id == productId);
      notifyListeners();

      print('🗑️ Removed favorite: $productId');
    } catch (e) {
      print('❌ Error removing favorite: $e');
      rethrow;
    }
  }
  void clearFavorites() {
    _favorites.clear();
    _isInitialized = false;
    notifyListeners();
    print('🧹 Favorites cleared');
  }

  Future<void> refreshFavorites() async {
    await loadFavorites();
  }
}