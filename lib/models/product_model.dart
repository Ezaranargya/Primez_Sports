import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOption {
  final String link;
  final String logoUrl;
  final String name;
  final double price;
  final int stock;
  final String storeName;

  const PurchaseOption({
    this.link = '',
    this.logoUrl = '',
    this.name = '',
    this.price = 0.0,
    this.stock = 0,
    this.storeName = '',
  });

  factory PurchaseOption.fromMap(Map<String, dynamic> map) {
    try {
      final link = map['link']?.toString() ?? '';
      final logoUrl = map['logoUrl']?.toString() ?? '';
      final name = map['name']?.toString() ?? '';

      double price = 0.0;
      final priceValue = map['price'];
      if (priceValue != null) {
        if (priceValue is int) {
          price = priceValue.toDouble();
        } else if (priceValue is double) {
          price = priceValue;
        } else {
          price = double.tryParse(priceValue.toString()) ?? 0.0;
        }
      }

      final stock = map['stock'] is int ? map['stock'] as int : 0;
      final storeName = map['storeName']?.toString() ?? '';

      return PurchaseOption(
        link: link,
        logoUrl: logoUrl,
        name: name,
        price: price,
        stock: stock,
        storeName: storeName,
      );
    } catch (e) {
      print('❌ Error parsing PurchaseOption: $e');
      print('📋 Map data: $map');
      return const PurchaseOption();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'link': link,
      'logoUrl': logoUrl,
      'name': name,
      'price': price,
      'stock': stock,
      'storeName': storeName,
    };
  }

  bool get isAssetLogo => logoUrl.isNotEmpty && !logoUrl.startsWith('http');

  String get formattedPrice {
    if (price == 0) return 'Harga tidak tersedia';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  PurchaseOption copyWith({
    String? link,
    String? logoUrl,
    String? name,
    double? price,
    int? stock,
    String? storeName,
  }) {
    return PurchaseOption(
      link: link ?? this.link,
      logoUrl: logoUrl ?? this.logoUrl,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      storeName: storeName ?? this.storeName,
    );
  }

  @override
  String toString() {
    return 'PurchaseOption(name: $name, storeName: $storeName, price: $formattedPrice, stock: $stock)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOption &&
          other.link == link &&
          other.name == name &&
          other.storeName == storeName);

  @override
  int get hashCode => Object.hash(link, name, storeName);
}

class Product {
  final String id;
  final String brand;
  final List<String> categories;
  final DateTime? createdAt;
  final String description;

  final String imageUrl;

  final String name;
  final double price;
  final List<PurchaseOption> purchaseOptions;
  final DateTime? updatedAt;
  final String userId;

  final String bannerUrl;

  Product({
    required this.id,
    this.brand = '',
    List<String>? categories,
    String? category,
    String? subCategory,
    this.createdAt,
    this.description = '',
    this.imageUrl = '',
    required this.name,
    this.price = 0.0,
    this.purchaseOptions = const [],
    this.updatedAt,
    this.userId = '',
    this.bannerUrl = '',
  }) : categories = categories ?? _buildCategories(category, subCategory);

  static List<String> _buildCategories(String? category, String? subCategory) {
    final result = <String>[];
    if (category != null && category.isNotEmpty) result.add(category);
    if (subCategory != null && subCategory.isNotEmpty) result.add(subCategory);
    return result;
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(data, doc.id);
  }

  factory Product.fromMap(Map<String, dynamic> data, String docId) {
    try {
      final brand = data['brand']?.toString() ?? '';

      List<String> categories = [];
      final categoriesData = data['categories'];
      if (categoriesData is List && categoriesData.isNotEmpty) {
        categories = categoriesData
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      final createdAt = _parseTimestamp(data['createdAt']);
      final description = data['description']?.toString() ?? '';
      final imageUrl = data['imageUrl']?.toString() ?? '';
      final name = data['name']?.toString() ?? 'Produk Tanpa Nama';
      final price = _parsePrice(data['price']);
      final purchaseOptions = _parsePurchaseOptions(data['purchaseOptions']);
      final updatedAt = _parseTimestamp(data['updatedAt']);
      final userId = data['userId']?.toString() ?? '';
      final bannerUrl = data['bannerUrl']?.toString() ?? '';

      return Product(
        id: docId,
        brand: brand,
        categories: categories,
        createdAt: createdAt,
        description: description,
        imageUrl: imageUrl,
        name: name,
        price: price,
        purchaseOptions: purchaseOptions,
        updatedAt: updatedAt,
        userId: userId,
        bannerUrl: bannerUrl,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing Product: $e');
      print('📋 Stack trace: $stackTrace');
      return Product(
        id: docId,
        name: 'Error Product',
        description: 'Error parsing: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'brand': brand,
      'categories': categories,
      'description': description,
      'imageUrl': imageUrl,
      'name': name,
      'price': price,
      'purchaseOptions': purchaseOptions.map((po) => po.toMap()).toList(),
      'userId': userId,
      'bannerUrl': bannerUrl,
    };

    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    return map;
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<PurchaseOption> _parsePurchaseOptions(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value
          .map((e) {
            try {
              if (e is Map<String, dynamic>) {
                return PurchaseOption.fromMap(e);
              } else if (e is Map) {
                return PurchaseOption.fromMap(Map<String, dynamic>.from(e));
              }
            } catch (_) {}
            return null;
          })
          .whereType<PurchaseOption>()
          .toList();
    }
    return [];
  }

  String get formattedPrice {
    if (price == 0) return 'Harga tidak tersedia';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  String get category => categories.isNotEmpty ? categories[0] : '';
  String get subCategory => categories.length > 1 ? categories[1] : '';

  /**
   * Getter untuk mengembalikan imageUrl. Ini menyelesaikan error 'displayImage'
   * yang mungkin digunakan di widget lain, setelah properti imageBase64 dihapus.
   */
  String get displayImage => imageUrl;

  Product copyWith({
    String? id,
    String? brand,
    List<String>? categories,
    String? category,
    String? subCategory,
    DateTime? createdAt,
    String? description,
    String? imageUrl,
    String? name,
    double? price,
    List<PurchaseOption>? purchaseOptions,
    DateTime? updatedAt,
    String? userId,
    String? bannerUrl,
  }) {
    List<String>? newCategories = categories;
    if (newCategories == null && (category != null || subCategory != null)) {
      newCategories = _buildCategories(
        category ?? this.category,
        subCategory ?? this.subCategory,
      );
    }

    return Product(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      categories: newCategories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      price: price ?? this.price,
      purchaseOptions: purchaseOptions ?? this.purchaseOptions,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, brand: $brand, price: $formattedPrice, categories: $categories)';
}