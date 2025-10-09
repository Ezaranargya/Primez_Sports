import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOption {
  final double price;
  final String storeName;
  final String logoUrl;
  final String link;

  PurchaseOption({
    required this.price,
    required this.storeName,
    required this.logoUrl,
    required this.link,
  });

  factory PurchaseOption.fromMap(Map<String, dynamic> data) {
    return PurchaseOption(
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0).toDouble(),
      storeName: data['storeName'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      link: data['link'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'storeName': storeName,
      'logoUrl': logoUrl,
      'link': link,
    };
  }

  PurchaseOption copyWith({
    double? price,
    String? storeName,
    String? logoUrl,
    String? link,
  }) {
    return PurchaseOption(
      price: price ?? this.price,
      storeName: storeName ?? this.storeName,
      logoUrl: logoUrl ?? this.logoUrl,
      link: link ?? this.link,
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String brand;
  final List<String> categories;
  final List<PurchaseOption> purchaseOptions;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.brand,
    this.categories = const [],
    this.purchaseOptions = const [],
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final List<dynamic> optionsData =
        (data['options'] ?? data['purchaseOptions'] ?? []) as List<dynamic>;

    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      categories: (data['categories'] is List)
          ? List<String>.from(data['categories'])
          : [],
      purchaseOptions: optionsData
          .map((e) => PurchaseOption.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'brand': brand,
      'categories': categories,
      'purchaseOptions':
          purchaseOptions.map((option) => option.toMap()).toList(),
    };
  }

  String get formattedPrice => price.toStringAsFixed(0);

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? description,
    String? brand,
    List<String>? categories,
    List<PurchaseOption>? purchaseOptions,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      purchaseOptions: purchaseOptions ?? this.purchaseOptions,
    );
  }
}
