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
}

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final List<PurchaseOption> purchaseOptions;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    this.purchaseOptions = const [],
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    List<PurchaseOption> optionsList = [];
    if (data['options'] != null && data['options'] is List) {
      optionsList = (data['options'] as List)
          .map((option) => PurchaseOption.fromMap(option as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      purchaseOptions: optionsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'options': purchaseOptions.map((option) => option.toMap()).toList(),
    };
  }

  String get formattedPrice {
    return price.toStringAsFixed(0);
  }
}
