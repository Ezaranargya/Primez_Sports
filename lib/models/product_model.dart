import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imagePath; 
  final String? bannerImage;
  final String description;
  final String brand;
  final List<String> categories;
  final List<PurchaseOption> purchaseOptions;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.bannerImage,
    required this.description,
    required this.brand,
    this.categories = const [],
    this.purchaseOptions = const [],
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      name: data['name'] ?? data['brandName'] ?? '',
      price: _parsePrice(data['price']),
      imagePath: data['imagePath'] ?? data['imageUrl'] ?? '',
      bannerImage: data['bannerImage'],
      description: data['description'] ?? '',
      brand: data['brand'] ?? data['brandName'] ?? '',
      categories: _parseCategories(data['categories']),
      purchaseOptions: _parseOptions(
        data['purchaseOptions'] ?? data['options'] ?? data['links'],
      ),
    );
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? data['brandName'] ?? '',
      price: _parsePrice(data['price']),
      imagePath: data['imagePath'] ?? data['imageUrl'] ?? '',
      bannerImage: data['bannerImage'],
      description: data['description'] ?? '',
      brand: data['brand'] ?? data['brandName'] ?? '',
      categories: _parseCategories(data['categories']),
      purchaseOptions: _parseOptions(
        data['purchaseOptions'] ?? data['options'] ?? data['links'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'bannerImage': bannerImage,
      'description': description,
      'brand': brand,
      'categories': categories,
      'purchaseOptions':
          purchaseOptions.map((option) => option.toMap()).toList(),
    };
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static List<String> _parseCategories(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<PurchaseOption> _parseOptions(dynamic value) {
    if (value is List) {
      return value
          .map((e) => PurchaseOption.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  String get formattedPrice => 'Rp${price.toStringAsFixed(0)}';

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imagePath,
    String? bannerImage,
    String? description,
    String? brand,
    List<String>? categories,
    List<PurchaseOption>? purchaseOptions,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      bannerImage: bannerImage ?? this.bannerImage,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      purchaseOptions: purchaseOptions ?? this.purchaseOptions,
    );
  }
}

class PurchaseOption {
  final String name;
  final String storeName;
  final double price;
  final String logoUrl;
  final String link;

  const PurchaseOption({
    required this.name,
    required this.storeName,
    required this.price,
    required this.logoUrl,
    required this.link,
  });

  bool get isAssetLogo => !logoUrl.startsWith('http');

  factory PurchaseOption.fromMap(Map<String, dynamic> map) {
    return PurchaseOption(
      name: map['name'] ?? map['platform'] ?? map['store'] ?? '',
      storeName: map['storeName'] ?? map['store'] ?? '',
      price: Product._parsePrice(map['price']),
      logoUrl: map['logoUrl'] ?? map['logo'] ?? '',
      link: map['link'] ?? map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'storeName': storeName,
      'price': price,
      'logoUrl': logoUrl,
      'link': link,
    };
  }
}
