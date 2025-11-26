import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityPost {
  final String id;
  final String brand;
  final String content;
  final String description;
  final DateTime createdAt;
  final String? imageUrl1;  
  final List<PostLink> links;
  final String userId;
  final String username;
  final String userEmail;
  final String? userPhotoUrl;

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
  }) {
    // ✅ TAMBAHKAN DEBUG DI CONSTRUCTOR
    debugPrint('✨ CommunityPost Created:');
    debugPrint('   ID: $id');
    debugPrint('   Username: $username');
    debugPrint('   imageUrl1: ${imageUrl1 == null ? "NULL" : "${imageUrl1!.length} chars"}');
    debugPrint('   userPhotoUrl: ${userPhotoUrl == null ? "NULL" : "${userPhotoUrl!.length} chars"}');
  }

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
    };
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map, String id) {
    print('🔄 CREATING CommunityPost FROM MAP:');
    print('   📍 ID: $id');
    
    final brand = map['brand'];
    final username = map['username'];
    final userId = map['userId'];
    final userEmail = map['userEmail'];
    final imageUrl1 = map['imageUrl1']; // ✅ Post image
    final userPhotoUrl = map['userPhotoUrl']; // ✅ User profile photo
    
    print('   🏷️ Brand: $brand (type: ${brand.runtimeType})');
    print('   👤 Username: $username (type: ${username?.runtimeType})');
    print('   🆔 UserId: $userId (type: ${userId.runtimeType})');
    print('   📧 UserEmail: $userEmail (type: ${userEmail.runtimeType})');
    
    // ✅ PENTING: Log panjang string untuk debugging
    if (imageUrl1 != null) {
      final imageStr = imageUrl1.toString();
      print('   🖼️ ImageUrl1: ${imageStr.substring(0, imageStr.length > 50 ? 50 : imageStr.length)}... (length: ${imageStr.length})');
    } else {
      print('   🖼️ ImageUrl1: NULL');
    }
    
    if (userPhotoUrl != null) {
      final photoStr = userPhotoUrl;
      print('   👤 UserPhotoUrl: ${photoStr.substring(0, photoStr.length > 50 ? 50 : photoStr.length)}... (length: ${photoStr.length})');
    } else {
      print('   👤 UserPhotoUrl: NULL or EMPTY');
    }
    
    print('   📝 Content: ${map['content']}');
    print('   📋 Description: ${map['description']}');
    
    // ✅ Parse username dengan multiple fallback
    String parsedUsername = 'User';
    
    if (username != null && username.toString().isNotEmpty && username.toString() != 'null') {
      parsedUsername = username.toString();
    } else if (userEmail != null && userEmail.toString().isNotEmpty) {
      parsedUsername = userEmail.toString().split('@')[0];
    } else if (userId != null) {
      parsedUsername = 'User${userId.toString().substring(0, 6)}';
    }
    
    print('   ✅ Final Username: "$parsedUsername"');
    
    // ✅ Parse imageUrl1 (IMPORTANT FIX)
    String? parsedImageUrl;
    if (imageUrl1 != null) {
      final imageStr = imageUrl1.toString();
      if (imageStr.isNotEmpty && imageStr != 'null') {
        parsedImageUrl = imageStr;
        print('   ✅ ImageUrl1 parsed: ${parsedImageUrl.length} characters');
      } else {
        print('   ⚠️ ImageUrl1 is empty or null string');
      }
    }
    
    // ✅ Parse userPhotoUrl
    String? parsedPhotoUrl;
    if (userPhotoUrl != null) {
      final photoStr = userPhotoUrl.toString();
      if (photoStr.isNotEmpty && photoStr != 'null') {
        parsedPhotoUrl = photoStr;
        print('   ✅ UserPhotoUrl parsed: ${parsedPhotoUrl.length} characters');
      }
    }
    
    return CommunityPost(
      id: id,
      brand: _parseString(brand, 'Brand'),
      content: _parseString(map['content'], 'Content'),
      description: _parseString(map['description'], 'Description'),
      createdAt: _parseTimestamp(map['createdAt']),
      imageUrl1: parsedImageUrl, // ✅ Use parsed value
      links: _parseLinks(map) ?? [],
      userId: _parseString(userId, 'UserId'),
      username: parsedUsername,
      userEmail: _parseString(userEmail, 'UserEmail'),
      userPhotoUrl: parsedPhotoUrl, // ✅ Use parsed value
    );
  }

  static String _parseString(dynamic value, String fieldName) {
    if (value == null) {
      print('   ⚠️ $fieldName is NULL, using default');
      return 'Unknown';
    }
    
    final result = value.toString();
    print('   ✅ $fieldName parsed: "$result"');
    return result;
  }

  static String? _parseNullableString(dynamic value, String fieldName) {
    if (value == null) {
      print('   ⚠️ $fieldName is NULL');
      return null;
    }
    
    final result = value.toString();
    if (result.isEmpty || result == 'null') {
      print('   ⚠️ $fieldName is EMPTY or "null"');
      return null;
    }
    
    print('   ✅ $fieldName parsed: "${result.substring(0, result.length > 30 ? 30 : result.length)}..."');
    return result;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      print('   ⚠️ Timestamp is NULL, using current time');
      return DateTime.now();
    }
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      print('   ✅ Timestamp parsed: $date');
      return date;
    }
    
    print('   ⚠️ Unknown timestamp type: ${timestamp.runtimeType}, using current time');
    return DateTime.now();
  }

  static List<PostLink> _parseLinks(Map<String, dynamic> map) {
    try {
      if (map['links'] is List) {
        final links = (map['links'] as List)
            .map((link) => PostLink.fromMap(link as Map<String, dynamic>))
            .toList();
        print('   ✅ Links parsed: ${links.length} items');
        return links;
      }
      print('   ⚠️ No links found or invalid format');
      return [];
    } catch (e) {
      print('   ❌ Error parsing links: $e');
      return [];
    }
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