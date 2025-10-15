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

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.bannerImage,
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
      imagePath: data['imagePath'] ?? data['imageUrl'] ?? '',
      bannerImage: data['bannerImage'],
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      categories: (data['categories'] is List)
          ? List<String>.from(data['categories'])
          : [],
      purchaseOptions: optionsData
          .map((e) =>
              PurchaseOption.fromMap(Map<String, dynamic>.from(e)))
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
      'imagePath': imagePath,
      'bannerImage': bannerImage,
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
    String? imagePath,
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
      name: map['name'] ?? '',
      storeName: map['storeName'] ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0),
      logoUrl: map['logoUrl'] ?? '',
      link: map['link'] ?? '',
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
