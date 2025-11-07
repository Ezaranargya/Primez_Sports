import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? fcmToken; 
  final bool isAdmin; 
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? favoriteProducts; 
  final Map<String, dynamic>? preferences; 

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.fcmToken,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
    this.favoriteProducts,
    this.preferences,
  });

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'isAdmin': isAdmin,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'favoriteProducts': favoriteProducts ?? [],
      'preferences': preferences ?? {},
    };
  }

  
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return UserModel(
      id: documentId ?? map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      favoriteProducts: map['favoriteProducts'] != null 
          ? List<String>.from(map['favoriteProducts']) 
          : [],
      preferences: map['preferences'] != null 
          ? Map<String, dynamic>.from(map['preferences']) 
          : {},
    );
  }

  
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, documentId: doc.id);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? fcmToken,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteProducts,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, isAdmin: $isAdmin, fcmToken: ${fcmToken != null ? "***" : "null"})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}