import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int get favoriteCount => _favorites.length;
  bool get hasFavorites => _favorites.isNotEmpty;

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
          final product = Product.fromMap(data, doc.id);
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

  
  Stream<List<Product>> favoritesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Product.fromMap(doc.data(), doc.id);
        } catch (e) {
          print('❌ Error parsing favorite: $e');
          return null;
        }
      }).whereType<Product>().toList();
    });
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

  Future<void> addFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(product.id)
          .set(product.toMap());

      if (!isFavorite(product.id)) {
        _favorites.add(product);
        notifyListeners();
      }

      print('❤️ Added to favorites: ${product.name}');
    } catch (e) {
      print('❌ Error adding favorite: $e');
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

  Future<void> clearAllFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _favorites.clear();
      notifyListeners();

      print('🧹 All favorites cleared from Firestore');
    } catch (e) {
      print('❌ Error clearing favorites: $e');
      rethrow;
    }
  }

  void clearFavorites() {
    _favorites.clear();
    _isInitialized = false;
    notifyListeners();
    print('🧹 Favorites cleared (local only)');
  }

  Future<void> refreshFavorites() async {
    await loadFavorites();
  }
}

class FavoriteIconButton extends StatelessWidget {
  final Product product;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteIconButton({
    Key? key,
    required this.product,
    this.iconSize = 24.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, provider, child) {
        final isFav = provider.isFavorite(product.id);
        
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav 
                ? (activeColor ?? Colors.red) 
                : (inactiveColor ?? Colors.grey),
            size: iconSize,
          ),
          onPressed: () async {
            try {
              await provider.toggleFavorite(product);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFav 
                        ? 'Dihapus dari favorit' 
                        : 'Ditambahkan ke favorit'
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class FavoritesListPage extends StatelessWidget {
  const FavoritesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, provider, child) {
              if (provider.hasFavorites) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Hapus Semua',
                  onPressed: () => _showClearAllDialog(context, provider),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasFavorites) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada favorit',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Produk yang kamu sukai akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshFavorites,
            child: ListView.builder(
              itemCount: provider.favorites.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final product = provider.favorites[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(product.brand),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(
                        context,
                        provider,
                        product,
                      ),
                    ),
                    onTap: () {
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    FavoriteProvider provider,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Favorit'),
        content: Text('Hapus "${product.name}" dari favorit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.removeFavorite(product.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, FavoriteProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Favorit'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus semua favorit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await provider.clearAllFavorites();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua favorit telah dihapus')),
                );
              }
            },
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class UserFavoritesStreamPage extends StatelessWidget {
  const UserFavoritesStreamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FavoriteProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya (Real-time)'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: provider.favoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];
          
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada favorit'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final product = favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(product.brand),
                  trailing: FavoriteIconButton(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
