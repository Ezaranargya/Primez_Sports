import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityPost {
  final String id;
  final String brand;
  final String content;        // ✅ Ini HARGA UTAMA (string)
  final String description;
  final DateTime createdAt;
  final String? imageUrl1;  
  final List<PostLink> links;
  final String userId;
  final String username;
  final String userEmail;
  final String? userPhotoUrl;
  
  // Field tambahan
  final String? title;         // ✅ Judul produk
  final double? mainProductPrice; // ✅ Parsed dari 'content'
  final String? mainCategory;
  final String? subCategory;
  final List<PurchaseOption>? purchaseOptions;

  CommunityPost({
    required this.id,
    required this.brand,
    required this.content,
    required this.description,
    required this.createdAt,
    this.imageUrl1,
    this.links = const [],
    required this.userId,
    required this.username,
    required this.userEmail,
    this.userPhotoUrl,
    this.title,
    this.mainProductPrice,
    this.mainCategory,
    this.subCategory,
    this.purchaseOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'content': content,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl1': imageUrl1,  
      'links': links.map((link) => link.toMap()).toList(),
      'userId': userId,
      'username': username,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'purchaseOptions': purchaseOptions?.map((option) => option.toMap()).toList(),
    };
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map, String id) {
    debugPrint('🔄 CREATING CommunityPost FROM MAP: $id');
    
    final brand = map['brand'] ?? '';
    final username = map['username'] ?? map['userName'] ?? '';
    final userId = map['userId'] ?? '';
    final userEmail = map['userEmail'] ?? '';
    final imageUrl1 = map['imageUrl1'];
    final userPhotoUrl = map['userPhotoUrl'] ?? map['photoURL'];
    final title = map['title'];
    final content = map['content'] ?? ''; // ✅ Ini HARGA (string)
    final mainCategory = map['mainCategory'];
    final subCategory = map['subCategory'];
    final description = map['description'] ?? '';
    
    // Parse username dengan multiple fallback
    String parsedUsername = 'User';
    
    if (username != null && username.toString().isNotEmpty && username.toString() != 'null') {
      parsedUsername = username.toString();
    } else if (userEmail != null && userEmail.toString().isNotEmpty) {
      parsedUsername = userEmail.toString().split('@')[0];
    } else if (userId != null) {
      parsedUsername = 'User${userId.toString().substring(0, userId.toString().length > 6 ? 6 : userId.toString().length)}';
    }
    
    // Parse imageUrl1
    String? parsedImageUrl;
    if (imageUrl1 != null) {
      final imageStr = imageUrl1.toString();
      if (imageStr.isNotEmpty && imageStr != 'null') {
        parsedImageUrl = imageStr;
      }
    }
    
    // Parse userPhotoUrl
    String? parsedPhotoUrl;
    if (userPhotoUrl != null) {
      final photoStr = userPhotoUrl.toString();
      if (photoStr.isNotEmpty && photoStr != 'null') {
        parsedPhotoUrl = photoStr;
      }
    }
    
    // ✅ FIX: Parse mainProductPrice dari field 'content'
    double? parsedMainProductPrice;
    if (content != null) {
      final contentStr = content.toString().trim();
      if (contentStr.isNotEmpty && contentStr != 'null') {
        // Hapus format Rp, titik, koma
        final cleanPrice = contentStr
            .replaceAll(RegExp(r'Rp'), '')
            .replaceAll(RegExp(r'\.'), '')
            .replaceAll(RegExp(r','), '')
            .replaceAll(RegExp(r'\s'), '')
            .trim();
        
        parsedMainProductPrice = double.tryParse(cleanPrice);
      }
    }
    
    // Parse purchaseOptions
    List<PurchaseOption>? parsedPurchaseOptions;
    if (map['purchaseOptions'] is List) {
      parsedPurchaseOptions = (map['purchaseOptions'] as List)
          .map((option) => PurchaseOption.fromMap(option as Map<String, dynamic>))
          .toList();
    }
    
    return CommunityPost(
      id: id,
      brand: _parseString(brand, 'Brand'),
      content: _parseString(content, 'Content'), // ✅ String harga
      description: _parseString(description, 'Description'),
      createdAt: _parseTimestamp(map['createdAt']),
      imageUrl1: parsedImageUrl,
      links: _parseLinks(map) ?? [],
      userId: _parseString(userId, 'UserId'),
      username: parsedUsername,
      userEmail: _parseString(userEmail, 'UserEmail'),
      userPhotoUrl: parsedPhotoUrl,
      title: _parseNullableString(title, 'Title'),
      mainProductPrice: parsedMainProductPrice, // ✅ Parsed dari content
      mainCategory: _parseNullableString(mainCategory, 'MainCategory'),
      subCategory: _parseNullableString(subCategory, 'SubCategory'),
      purchaseOptions: parsedPurchaseOptions,
    );
  }

  static String _parseString(dynamic value, String fieldName) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _parseNullableString(dynamic value, String fieldName) {
    if (value == null) return null;
    final result = value.toString();
    if (result.isEmpty || result == 'null') return null;
    return result;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  static List<PostLink>? _parseLinks(Map<String, dynamic> map) {
    try {
      if (map['links'] is List) {
        final links = (map['links'] as List)
            .map((link) => PostLink.fromMap(link as Map<String, dynamic>))
            .toList();
        return links;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing links: $e');
      return [];
    }
  }
}

class PurchaseOption {
  final String platform;
  final String url;
  final String? logoUrl;
  final double? price;

  PurchaseOption({
    required this.platform,
    required this.url,
    this.logoUrl,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'url': url,
      'logoUrl': logoUrl,
      'price': price,
    };
  }

  factory PurchaseOption.fromMap(Map<String, dynamic> map) {
    return PurchaseOption(
      platform: map['platform'] ?? '',
      url: map['url'] ?? '',
      logoUrl: map['logoUrl'],
      price: (map['price'] is num) 
          ? (map['price'] as num).toDouble() 
          : double.tryParse(map['price']?.toString() ?? ''),
    );
  }

  String get formattedPrice {
    if (price == null) return '';
    return 'Rp ${price!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

class PostLink {
  final String logoUrl; // ✅ Perbaikan: gunakan logoUrl konsisten
  final double price;
  final String store;
  final String url;

  PostLink({
    required this.logoUrl,
    required this.price,
    required this.store,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'logoUrl': logoUrl,  // ✅ Perbaikan: gunakan logoUrl konsisten
      'price': price,
      'store': store,
      'url': url,
    };
  }

  factory PostLink.fromMap(Map<String, dynamic> map) {
    return PostLink(
      logoUrl: map['logoUrl'] ?? map['logoUrl1'] ?? '',  // ✅ Perbaikan: handle both fields
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