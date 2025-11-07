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

  factory PurchaseOption.fromJson(Map<String, dynamic> json) {
    return PurchaseOption(
      name: json['name'] ?? '',
      storeName: json['storeName'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] ?? 0.0),
      logoUrl: json['logoUrl'] ?? '',
      link: json['link'] ?? '',
    );
  }

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

  Map<String, dynamic> toJson() => toMap();

  PurchaseOption copyWith({
    String? name,
    String? storeName,
    double? price,
    String? logoUrl,
    String? link,
  }) {
    return PurchaseOption(
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      logoUrl: logoUrl ?? this.logoUrl,
      link: link ?? this.link,
    );
  }
}
