import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String brand;
  final String content;
  final String description;
  final DateTime createdAt;
  final String? imageUrl1;  
  final List<PostLink> links;

  CommunityPost({
    required this.id,
    required this.brand,
    required this.content,
    required this.description,
    required this.createdAt,
    this.imageUrl1,
    this.links = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'content': content,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl1': imageUrl1,  
      'links': links.map((link) => link.toMap()).toList(),
    };
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map, String id) {
    return CommunityPost(
      id: id,
      brand: map['brand'] ?? '',
      content: map['content'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl1: map['imageUrl1'] ?? map['imageUrl'],  
      links: map['links'] != null
          ? (map['links'] as List)
              .map((link) => PostLink.fromMap(link as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class PostLink {
  final String logoUrl1; 
  final double price;
  final String store;
  final String url;

  PostLink({
    required this.logoUrl1,
    required this.price,
    required this.store,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'logoUrl1': logoUrl1,  
      'price': price,
      'store': store,
      'url': url,
    };
  }

  factory PostLink.fromMap(Map<String, dynamic> map) {
    return PostLink(
      logoUrl1: map['logoUrl1'] ?? map['logoUrl'] ?? '',  
      price: (map['price'] is num) 
          ? (map['price'] as num).toDouble() 
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0,
      store: map['store'] ?? '',
      url: map['url'] ?? '',
    );
  }

  String get formattedPrice {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}