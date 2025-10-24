import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// 🔹 PURCHASE OPTION MODEL (UNIFIED)
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

  /// ============================================================
  /// 🔹 Factory from Map (FLEXIBLE PARSING)
  /// ============================================================
  factory PurchaseOption.fromMap(Map<String, dynamic> map) {
    try {
      // Parse id
      final id = map['id']?.toString() ?? '';

      // Parse name - support multiple field names
      final name = map['name']?.toString() ??
          map['platform']?.toString() ??
          map['store']?.toString() ??
          '';

      // Parse storeName
      final storeName = map['storeName']?.toString() ??
          map['store']?.toString() ??
          '';

      // Parse size (for products with size options)
      final size = map['size']?.toString() ??
          map['ukuran']?.toString() ??
          '';

      // Parse price - support multiple types and field names
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


      // Parse logoUrl
      final logoUrl = map['logoUrl']?.toString() ??
          map['logo']?.toString() ??
          '';

      // Parse link
      final link = map['link']?.toString() ??
          map['url']?.toString() ??
          '';

      return PurchaseOption(
        id: id,
        name: name,
        storeName: storeName,
        size: size,
        price: price,
        logoUrl: logoUrl,
        link: link,
      );
    } catch (e) {
      print('❌ Error parsing PurchaseOption: $e');
      print('📋 Map data: $map');
      return const PurchaseOption();
    }
  }

  /// ============================================================
  /// 🔹 Convert to Map
  /// ============================================================
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (id.isNotEmpty) map['id'] = id;
    if (name.isNotEmpty) map['name'] = name;
    if (storeName.isNotEmpty) map['storeName'] = storeName;
    if (size.isNotEmpty) {
      map['size'] = size;
      map['ukuran'] = size; // Compatibility
    }

    map['price'] = price;
    map['harga'] = price; // Compatibility
    map['stock'] = stock;

    if (logoUrl.isNotEmpty) map['logoUrl'] = logoUrl;
    if (link.isNotEmpty) map['link'] = link;

    return map;
  }

  /// ============================================================
  /// 🔹 Check if logo is asset or network
  /// ============================================================
  bool get isAssetLogo => logoUrl.isNotEmpty && !logoUrl.startsWith('http');

  /// ============================================================
  /// 🔹 Formatted Price Display (Rupiah)
  /// ============================================================
  String get formattedPrice {
    if (price == 0) return 'Harga tidak tersedia';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  /// ============================================================
  /// 🔹 Copy With
  /// ============================================================
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
    parts.add('price: ${formattedPrice}');
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
/// 🔹 PRODUCT MODEL
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
  final String? imageBase64;
  final String userId;
  final List<String> categories;
  final List<PurchaseOption> purchaseOptions;

  const Product({
    required this.id,
    required this.name,
    this.brand = '',
    required this.description,
    required this.price,
    this.category = '',
    this.subCategory = '',
    required this.imageUrl,
    this.bannerImage = '',
    this.imageBase64,
    this.userId = '',
    this.categories = const [],
    this.purchaseOptions = const [],
  });

  /// ============================================================
  /// 🔹 Factory from Map (SUPER FLEXIBLE PARSING)
  /// ============================================================
  factory Product.fromMap(Map<String, dynamic> data, String docId) {
    try {
      // Parse name - support multiple field names
      final name = data['name']?.toString() ??
          data['nama']?.toString() ??
          data['brandName']?.toString() ??
          'Produk Tanpa Nama';

      // Parse brand
      final brand = data['brand']?.toString() ??
          data['brandName']?.toString() ??
          '';

      // Parse description
      final description = data['description']?.toString() ??
          data['deskripsi']?.toString() ??
          '';

      // Parse price - support int, double, and string
      final price = _parsePrice(data['price'] ?? data['harga'] ?? 0);

      // Parse category & subCategory
      final category = data['category']?.toString() ??
          data['kategori']?.toString() ??
          '';
      final subCategory = data['subCategory']?.toString() ??
          data['subKategori']?.toString() ??
          '';

      // Parse imageUrl
      final imageUrl = data['imageUrl']?.toString() ??
          data['imagePath']?.toString() ??
          '';

      // Parse bannerImage
      final bannerImage = data['bannerImage']?.toString() ?? '';

      // Parse imageBase64
      final imageBase64 = data['imageBase64']?.toString();

      // Parse userId
      final userId = data['userId']?.toString() ?? '';

      // Parse categories array
      List<String> categories = [];
      if (data['categories'] is List && (data['categories'] as List).isNotEmpty) {
        categories = (data['categories'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        // Fallback: buat categories dari category & subCategory
        if (category.isNotEmpty) categories.add(category);
        if (subCategory.isNotEmpty) categories.add(subCategory);
      }

      // Parse purchaseOptions - support multiple field names
      final purchaseOptions = _parsePurchaseOptions(
        data['purchaseOptions'] ??
            data['opsiPembelian'] ??
            data['options'] ??
            data['links'],
      );

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
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing Product from Firestore: $e');
      print('📋 Document ID: $docId');
      print('📋 Data: $data');
      print('📋 Stack trace: $stackTrace');

      // Return minimal product on error
      return Product(
        id: docId,
        name: 'Error Product',
        description: 'Error parsing data: $e',
        price: 0.0,
        imageUrl: '',
      );
    }
  }

  /// ============================================================
  /// 🔹 Factory from Firestore DocumentSnapshot
  /// ============================================================
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(data, doc.id);
  }

  /// ============================================================
  /// 🔹 Convert to Map for Firestore
  /// ============================================================
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'nama': name, // Compatibility
      'brand': brand,
      'brandName': brand, // Compatibility
      'description': description,
      'deskripsi': description, // Compatibility
      'price': price,
      'harga': price, // Compatibility
      'imageUrl': imageUrl,
      'bannerImage': bannerImage,
      'userId': userId,
    };

    // Add category fields if not empty
    if (category.isNotEmpty) {
      map['category'] = category;
      map['kategori'] = category; // Compatibility
    }
    if (subCategory.isNotEmpty) {
      map['subCategory'] = subCategory;
      map['subKategori'] = subCategory; // Compatibility
    }

    // Add imageBase64 if exists
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      map['imageBase64'] = imageBase64;
    }

    // Add categories array - prioritize from categories field, fallback to category+subCategory
    if (categories.isNotEmpty) {
      map['categories'] = categories;
    } else {
      final cats = <String>[];
      if (category.isNotEmpty) cats.add(category);
      if (subCategory.isNotEmpty) cats.add(subCategory);
      if (cats.isNotEmpty) map['categories'] = cats;
    }

    // Add purchaseOptions
    if (purchaseOptions.isNotEmpty) {
      map['purchaseOptions'] = purchaseOptions.map((po) => po.toMap()).toList();
      map['opsiPembelian'] = purchaseOptions.map((po) => po.toMap()).toList(); // Compatibility
    }

    return map;
  }

  /// ============================================================
  /// 🔹 Helper: Parse Price (int/double/string)
  /// ============================================================
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// ============================================================
  /// 🔹 Helper: Parse Purchase Options
  /// ============================================================
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
            } catch (error) {
              print('⚠️ Error parsing purchase option: $error');
            }
            return null;
          })
          .whereType<PurchaseOption>()
          .toList();
    }
    return [];
  }

  /// ============================================================
  /// 🔹 Formatted Price Display (Rupiah)
  /// ============================================================
  String get formattedPrice {
    if (price == 0) return 'Harga tidak tersedia';
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  /// ============================================================
  /// 🔹 Get Price as Int
  /// ============================================================
  int get priceAsInt => price.toInt();

  /// ============================================================
  /// 🔹 Copy With
  /// ============================================================
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
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, brand: $brand, price: ${formattedPrice}, categories: $categories)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}