import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// 🔹 PURCHASE OPTION MODEL
/// ============================================================
class PurchaseOption {
  final String id;
  final String name;
  final String storeName;
  final String size;
  final double price;
  final int stock;
  final String logoUrl;
  final String link;

  const PurchaseOption({
    this.id = '',
    this.name = '',
    this.storeName = '',
    this.size = '',
    this.price = 0.0,
    this.stock = 0,
    this.logoUrl = '',
    this.link = '',
  });

  factory PurchaseOption.fromMap(Map<String, dynamic> map) {
    try {
      final id = map['id']?.toString() ?? '';
      final name = map['name']?.toString() ??
          map['platform']?.toString() ??
          map['store']?.toString() ??
          '';
      final storeName = map['storeName']?.toString() ??
          map['store']?.toString() ??
          '';
      final size = map['size']?.toString() ?? map['ukuran']?.toString() ?? '';

      double price = 0.0;
      final priceValue = map['price'] ?? map['harga'];
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
      final logoUrl =
          map['logoUrl']?.toString() ?? map['logo']?.toString() ?? '';
      final link = map['link']?.toString() ?? map['url']?.toString() ?? '';

      return PurchaseOption(
        id: id,
        name: name,
        storeName: storeName,
        size: size,
        price: price,
        stock: stock,
        logoUrl: logoUrl,
        link: link,
      );
    } catch (e) {
      print('❌ Error parsing PurchaseOption: $e');
      print('📋 Map data: $map');
      return const PurchaseOption();
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id.isNotEmpty) map['id'] = id;
    if (name.isNotEmpty) map['name'] = name;
    if (storeName.isNotEmpty) map['storeName'] = storeName;
    if (size.isNotEmpty) map['size'] = size;
    map['price'] = price;
    map['stock'] = stock;
    if (logoUrl.isNotEmpty) map['logoUrl'] = logoUrl;
    if (link.isNotEmpty) map['link'] = link;
    return map;
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
    String? id,
    String? name,
    String? storeName,
    String? size,
    double? price,
    int? stock,
    String? logoUrl,
    String? link,
  }) {
    return PurchaseOption(
      id: id ?? this.id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      size: size ?? this.size,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      logoUrl: logoUrl ?? this.logoUrl,
      link: link ?? this.link,
    );
  }

  @override
  String toString() {
    final parts = <String>['PurchaseOption('];
    if (id.isNotEmpty) parts.add('id: $id, ');
    if (name.isNotEmpty) parts.add('name: $name, ');
    if (size.isNotEmpty) parts.add('size: $size, ');
    parts.add('price: $formattedPrice');
    if (stock > 0) parts.add(', stock: $stock');
    parts.add(')');
    return parts.join();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOption &&
          other.id == id &&
          other.name == name &&
          other.size == size &&
          other.storeName == storeName);

  @override
  int get hashCode => Object.hash(id, name, size, storeName);
}

/// ============================================================
/// 🔹 PRODUCT MODEL (CLEAN VERSION)
/// ============================================================
class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final String category;
  final String subCategory;
  final String imageUrl;
  final String bannerImage;
  final String imageBase64;
  final String userId;
  final List<String> categories;
  final List<PurchaseOption> purchaseOptions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.brand = '',
    required this.description,
    required this.price,
    this.category = '',
    this.subCategory = '',
    this.imageUrl = '',
    this.bannerImage = '',
    this.imageBase64 = '',
    this.userId = '',
    this.categories = const [],
    this.purchaseOptions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(data, doc.id);
  }

  factory Product.fromMap(Map<String, dynamic> data, String docId) {
    try {
      final name = data['name']?.toString() ??
          data['nama']?.toString() ??
          'Produk Tanpa Nama';

      final brand = data['brand']?.toString() ??
          data['brandName']?.toString() ??
          '';

      final description = data['description']?.toString() ??
          data['deskripsi']?.toString() ??
          '';

      final price = _parsePrice(data['price'] ?? data['harga'] ?? 0);

      final category = data['category']?.toString() ??
          data['kategori']?.toString() ??
          '';
      final subCategory = data['subCategory']?.toString() ??
          data['subKategori']?.toString() ??
          '';

      final imageUrl = data['imageUrl']?.toString() ??
          data['imagePath']?.toString() ??
          '';
      final bannerImage = data['bannerImage']?.toString() ?? '';
      final imageBase64 = data['imageBase64']?.toString() ?? '';
      final userId = data['userId']?.toString() ?? '';

      List<String> categories = [];
      final categoriesData = data['categories'];
      if (categoriesData is String && categoriesData.isNotEmpty) {
        categories = [categoriesData];
      } else if (categoriesData is List && categoriesData.isNotEmpty) {
        categories = categoriesData
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        if (category.isNotEmpty) categories.add(category);
        if (subCategory.isNotEmpty) categories.add(subCategory);
      }

      final purchaseOptions = _parsePurchaseOptions(
        data['purchaseOptions'] ??
            data['opsiPembelian'] ??
            data['options'] ??
            data['links'],
      );

      final createdAt = _parseTimestamp(data['createdAt']);
      final updatedAt = _parseTimestamp(data['updatedAt']);

      return Product(
        id: docId,
        name: name,
        brand: brand,
        description: description,
        price: price,
        category: category,
        subCategory: subCategory,
        imageUrl: imageUrl,
        bannerImage: bannerImage,
        imageBase64: imageBase64,
        userId: userId,
        categories: categories,
        purchaseOptions: purchaseOptions,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing Product: $e');
      print('📋 Stack trace: $stackTrace');
      return Product(
        id: docId,
        name: 'Error Product',
        description: 'Error parsing: $e',
        price: 0.0,
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'brand': brand,
      'description': description,
      'price': price,
      'userId': userId,
    };

    if (imageUrl.isNotEmpty) map['imageUrl'] = imageUrl;
    if (bannerImage.isNotEmpty) map['bannerImage'] = bannerImage;
    if (imageBase64.isNotEmpty) map['imageBase64'] = imageBase64;

    if (category.isNotEmpty) map['category'] = category;
    if (subCategory.isNotEmpty) map['subCategory'] = subCategory;

    if (categories.isNotEmpty) {
      map['categories'] = categories;
    } else {
      final cats = <String>[];
      if (category.isNotEmpty) cats.add(category);
      if (subCategory.isNotEmpty) cats.add(subCategory);
      if (cats.isNotEmpty) map['categories'] = cats;
    }

    if (purchaseOptions.isNotEmpty) {
      map['purchaseOptions'] =
          purchaseOptions.map((po) => po.toMap()).toList();
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

  bool get shouldUseBase64 => imageBase64.isNotEmpty;
  String get displayImage => shouldUseBase64 ? imageBase64 : imageUrl;

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    double? price,
    String? category,
    String? subCategory,
    String? imageUrl,
    String? bannerImage,
    String? imageBase64,
    String? userId,
    List<String>? categories,
    List<PurchaseOption>? purchaseOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerImage: bannerImage ?? this.bannerImage,
      imageBase64: imageBase64 ?? this.imageBase64,
      userId: userId ?? this.userId,
      categories: categories ?? this.categories,
      purchaseOptions: purchaseOptions ?? this.purchaseOptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, brand: $brand, price: $formattedPrice)';
}
